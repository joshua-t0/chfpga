# HIRAX FFT CHAN LOC constraints (PFB + fft_wideband_real BRAMs for CHAN[0]-CHAN[15])
# Refer to commented pblock definitions in ice_physical_constraints_ct.xdc for region bounds.

# Below are the pblock definitions for the HIRAX FFT CHANs. These are for reference only. We no longer use Pblocks to constraints the channelizers, but instead LOC each BRAM in place below into a logical data flow.

# create_pblock CHAN0
# # add_cells_to_pblock [get_pblocks CHAN0] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[0].chan0}]]
# resize_pblock [get_pblocks CHAN0] -add {SLICE_X8Y175:SLICE_X151Y199}
# resize_pblock [get_pblocks CHAN0] -add {DSP48_X0Y70:DSP48_X9Y79}
# resize_pblock [get_pblocks CHAN0] -add {RAMB18_X1Y70:RAMB18_X9Y79 RAMB18_X0Y74:RAMB18_X0Y79}
# resize_pblock [get_pblocks CHAN0] -add {RAMB36_X1Y35:RAMB36_X9Y39 RAMB36_X0Y37:RAMB36_X0Y39}
# #set_property IS_SOFT FALSE [get_pblocks CHAN0]
# # add_cells_to_pblock [get_pblocks CHAN1] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[1].chan0}]]
# resize_pblock [get_pblocks CHAN1] -add {SLICE_X8Y150:SLICE_X151Y174}
# resize_pblock [get_pblocks CHAN1] -add {DSP48_X0Y60:DSP48_X9Y69}
# resize_pblock [get_pblocks CHAN1] -add {RAMB18_X1Y60:RAMB18_X9Y69 RAMB18_X0Y60:RAMB18_X0Y65}
# resize_pblock [get_pblocks CHAN1] -add {RAMB36_X1Y30:RAMB36_X9Y34 RAMB36_X0Y30:RAMB36_X0Y32}
# #set_property IS_SOFT FALSE [get_pblocks CHAN1]
# # add_cells_to_pblock [get_pblocks CHAN1] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[1].chan0}]]

# create_pblock CHAN2
# # add_cells_to_pblock [get_pblocks CHAN2] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[2].chan0}]]
# resize_pblock [get_pblocks CHAN2] -add {SLICE_X8Y125:SLICE_X143Y149}
# resize_pblock [get_pblocks CHAN2] -add {DSP48_X0Y50:DSP48_X9Y59}
# resize_pblock [get_pblocks CHAN2] -add {RAMB18_X1Y50:RAMB18_X8Y59 RAMB18_X0Y54:RAMB18_X0Y59}
# resize_pblock [get_pblocks CHAN2] -add {RAMB36_X1Y25:RAMB36_X8Y29 RAMB36_X0Y27:RAMB36_X0Y29}
# #set_property IS_SOFT FALSE [get_pblocks CHAN2]

# # add_cells_to_pblock [get_pblocks CHAN2] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[2].chan0}]]
# create_pblock CHAN3
# # add_cells_to_pblock [get_pblocks CHAN3] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[3].chan0}]]
# resize_pblock [get_pblocks CHAN3] -add {SLICE_X8Y100:SLICE_X143Y124}
# resize_pblock [get_pblocks CHAN3] -add {DSP48_X0Y40:DSP48_X9Y49}
# resize_pblock [get_pblocks CHAN3] -add {RAMB18_X1Y40:RAMB18_X8Y49 RAMB18_X0Y44:RAMB18_X0Y49}
# resize_pblock [get_pblocks CHAN3] -add {RAMB36_X1Y20:RAMB36_X8Y24 RAMB36_X0Y22:RAMB36_X0Y24}
# #set_property IS_SOFT FALSE [get_pblocks CHAN3]

# # add_cells_to_pblock [get_pblocks CHAN3] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[3].chan0}]]

# create_pblock CHAN4
# # add_cells_to_pblock [get_pblocks CHAN4] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[4].chan0}]]
# resize_pblock [get_pblocks CHAN4] -add {SLICE_X8Y0:SLICE_X143Y24}
# resize_pblock [get_pblocks CHAN4] -add {DSP48_X0Y0:DSP48_X9Y9}
# resize_pblock [get_pblocks CHAN4] -add {RAMB18_X1Y0:RAMB18_X8Y9 RAMB18_X0Y0:RAMB18_X0Y5}
# resize_pblock [get_pblocks CHAN4] -add {RAMB36_X1Y0:RAMB36_X8Y4 RAMB36_X0Y0:RAMB36_X0Y2}
# #set_property IS_SOFT FALSE [get_pblocks CHAN4]
# # add_cells_to_pblock [get_pblocks CHAN4] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[4].chan0}]]

# create_pblock CHAN5
# # add_cells_to_pblock [get_pblocks CHAN5] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[5].chan0}]]
# resize_pblock [get_pblocks CHAN5] -add {SLICE_X8Y25:SLICE_X143Y49}
# resize_pblock [get_pblocks CHAN5] -add {DSP48_X0Y10:DSP48_X9Y19}
# resize_pblock [get_pblocks CHAN5] -add {RAMB18_X1Y10:RAMB18_X8Y19 RAMB18_X0Y10:RAMB18_X0Y15}
# resize_pblock [get_pblocks CHAN5] -add {RAMB36_X1Y5:RAMB36_X8Y9 RAMB36_X0Y5:RAMB36_X0Y7}
# #set_property IS_SOFT FALSE [get_pblocks CHAN5]
# # add_cells_to_pblock [get_pblocks CHAN5] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[5].chan0}]]

# create_pblock CHAN6
# # add_cells_to_pblock [get_pblocks CHAN6] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[6].chan0}]]
# resize_pblock [get_pblocks CHAN6] -add {SLICE_X8Y50:SLICE_X143Y74}
# resize_pblock [get_pblocks CHAN6] -add {DSP48_X0Y20:DSP48_X9Y29}
# resize_pblock [get_pblocks CHAN6] -add {RAMB18_X1Y20:RAMB18_X8Y29 RAMB18_X0Y20:RAMB18_X0Y25}
# resize_pblock [get_pblocks CHAN6] -add {RAMB36_X1Y10:RAMB36_X8Y14 RAMB36_X0Y10:RAMB36_X0Y12}
# #set_property IS_SOFT FALSE [get_pblocks CHAN6]
# # add_cells_to_pblock [get_pblocks CHAN6] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[6].chan0}]]

# create_pblock CHAN7
# # add_cells_to_pblock [get_pblocks CHAN7] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[7].chan0}]]
# resize_pblock [get_pblocks CHAN7] -add {SLICE_X8Y75:SLICE_X143Y99}
# resize_pblock [get_pblocks CHAN7] -add {DSP48_X0Y30:DSP48_X9Y39}
# resize_pblock [get_pblocks CHAN7] -add {RAMB18_X1Y30:RAMB18_X8Y39 RAMB18_X0Y34:RAMB18_X0Y39}
# resize_pblock [get_pblocks CHAN7] -add {RAMB36_X1Y15:RAMB36_X8Y19 RAMB36_X0Y17:RAMB36_X0Y19}
# #set_property IS_SOFT FALSE [get_pblocks CHAN7]
# # add_cells_to_pblock [get_pblocks CHAN7] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[7].chan0}]]

# create_pblock CHAN8
# # add_cells_to_pblock [get_pblocks CHAN8] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[8].chan0}]]
# resize_pblock [get_pblocks CHAN8] -add {SLICE_X8Y275:SLICE_X147Y299}
# resize_pblock [get_pblocks CHAN8] -add {DSP48_X0Y110:DSP48_X9Y119}
# resize_pblock [get_pblocks CHAN8] -add {RAMB18_X1Y110:RAMB18_X8Y119 RAMB18_X0Y110:RAMB18_X0Y115}
# resize_pblock [get_pblocks CHAN8] -add {RAMB36_X1Y55:RAMB36_X8Y59 RAMB36_X0Y55:RAMB36_X0Y57}
# #set_property IS_SOFT FALSE [get_pblocks CHAN8]
# # add_cells_to_pblock [get_pblocks CHAN8] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[8].chan0}]]

# create_pblock CHAN14
# # add_cells_to_pblock [get_pblocks CHAN14] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[14].chan0}]]
# resize_pblock [get_pblocks CHAN14] -add {SLICE_X8Y375:SLICE_X147Y399}
# resize_pblock [get_pblocks CHAN14] -add {DSP48_X0Y150:DSP48_X9Y159}
# resize_pblock [get_pblocks CHAN14] -add {RAMB18_X1Y150:RAMB18_X8Y159 RAMB18_X0Y154:RAMB18_X0Y159}
# resize_pblock [get_pblocks CHAN14] -add {RAMB36_X1Y75:RAMB36_X8Y79 RAMB36_X0Y77:RAMB36_X0Y79}
# #set_property IS_SOFT FALSE [get_pblocks CHAN14]
# # add_cells_to_pblock [get_pblocks CHAN14] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[14].chan0}]]

# create_pblock CHAN15
# # add_cells_to_pblock [get_pblocks CHAN15] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[15].chan0}]]
# resize_pblock [get_pblocks CHAN15] -add {SLICE_X8Y350:SLICE_X147Y374}
# resize_pblock [get_pblocks CHAN15] -add {DSP48_X0Y140:DSP48_X9Y149}
# resize_pblock [get_pblocks CHAN15] -add {RAMB18_X1Y140:RAMB18_X8Y149 RAMB18_X0Y140:RAMB18_X0Y145}
# resize_pblock [get_pblocks CHAN15] -add {RAMB36_X1Y70:RAMB36_X8Y74 RAMB36_X0Y70:RAMB36_X0Y72}
# #set_property IS_SOFT FALSE [get_pblocks CHAN15]
# # add_cells_to_pblock [get_pblocks CHAN15] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[15].chan0}]]

# create_pblock CHAN11
# # add_cells_to_pblock [get_pblocks CHAN11] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[11].chan0}]]
# resize_pblock [get_pblocks CHAN11] -add {SLICE_X8Y325:SLICE_X147Y349}
# resize_pblock [get_pblocks CHAN11] -add {DSP48_X0Y130:DSP48_X9Y139}
# resize_pblock [get_pblocks CHAN11] -add {RAMB18_X1Y130:RAMB18_X8Y139 RAMB18_X0Y130:RAMB18_X0Y135}
# resize_pblock [get_pblocks CHAN11] -add {RAMB36_X1Y65:RAMB36_X8Y69 RAMB36_X0Y65:RAMB36_X0Y67}
# #set_property IS_SOFT FALSE [get_pblocks CHAN11]
# # add_cells_to_pblock [get_pblocks CHAN11] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[11].chan0}]]

# create_pblock CHAN10
# # add_cells_to_pblock [get_pblocks CHAN10] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[10].chan0}]]
# resize_pblock [get_pblocks CHAN10] -add {SLICE_X8Y300:SLICE_X147Y324}
# resize_pblock [get_pblocks CHAN10] -add {DSP48_X0Y120:DSP48_X9Y129}
# resize_pblock [get_pblocks CHAN10] -add {RAMB18_X1Y120:RAMB18_X8Y129 RAMB18_X0Y124:RAMB18_X0Y129}
# resize_pblock [get_pblocks CHAN10] -add {RAMB36_X1Y60:RAMB36_X8Y64 RAMB36_X0Y62:RAMB36_X0Y64}
# #set_property IS_SOFT FALSE [get_pblocks CHAN10]
# # add_cells_to_pblock [get_pblocks CHAN10] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[10].chan0}]]

# create_pblock CHAN9
# # add_cells_to_pblock [get_pblocks CHAN9] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[9].chan0}]]
# resize_pblock [get_pblocks CHAN9] -add {SLICE_X8Y250:SLICE_X147Y274}
# resize_pblock [get_pblocks CHAN9] -add {DSP48_X0Y100:DSP48_X9Y109}
# resize_pblock [get_pblocks CHAN9] -add {RAMB18_X1Y100:RAMB18_X8Y109 RAMB18_X0Y100:RAMB18_X0Y105}
# resize_pblock [get_pblocks CHAN9] -add {RAMB36_X1Y50:RAMB36_X8Y54 RAMB36_X0Y50:RAMB36_X0Y52}
# #set_property IS_SOFT FALSE [get_pblocks CHAN9]
# # add_cells_to_pblock [get_pblocks CHAN9] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[9].chan0}]]


# create_pblock CHAN12
# # add_cells_to_pblock [get_pblocks CHAN12] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[12].chan0}]]
# resize_pblock [get_pblocks CHAN12] -add {SLICE_X8Y200:SLICE_X151Y224}
# resize_pblock [get_pblocks CHAN12] -add {DSP48_X0Y80:DSP48_X9Y89}
# resize_pblock [get_pblocks CHAN12] -add {RAMB18_X1Y80:RAMB18_X9Y89 RAMB18_X0Y80:RAMB18_X0Y85}
# resize_pblock [get_pblocks CHAN12] -add {RAMB36_X1Y40:RAMB36_X9Y44 RAMB36_X0Y40:RAMB36_X0Y42}
# #set_property IS_SOFT FALSE [get_pblocks CHAN12]
# # add_cells_to_pblock [get_pblocks CHAN12] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[12].chan0}]]

# create_pblock CHAN13
# # add_cells_to_pblock [get_pblocks CHAN13] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[13].chan0}]]
# resize_pblock [get_pblocks CHAN13] -add {SLICE_X148Y225:SLICE_X159Y234 SLICE_X8Y225:SLICE_X147Y249}
# resize_pblock [get_pblocks CHAN13] -add {DSP48_X0Y90:DSP48_X9Y99}
# resize_pblock [get_pblocks CHAN13] -add {RAMB18_X9Y90:RAMB18_X9Y93 RAMB18_X1Y90:RAMB18_X8Y99}
# resize_pblock [get_pblocks CHAN13] -add {RAMB36_X9Y45:RAMB36_X9Y46 RAMB36_X1Y45:RAMB36_X8Y49}
# #set_property IS_SOFT FALSE [get_pblocks CHAN13]
# # add_cells_to_pblock [get_pblocks CHAN13] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[13].chan0}]]


########################################################
# PFB/FFT LOC BRAM LOC constraints
########################################################

# PFB BRAMs -- CHAN[0] (base Y70)
# PFB BRAMs -- 4 columns (one per input), 7 rows each
# Bottom-up per column: rom1, rom2, rom3, rom4 (co-addressed coeffs), first_tap, tap2, tap3 (delay chain)
# Column X1 -- pol1_in1
set_property LOC RAMB18_X1Y70 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y71 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y72 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y73 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y74 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y75 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y76 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X2 -- pol1_in2
set_property LOC RAMB18_X2Y70 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y71 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y72 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y73 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y74 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y75 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y76 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X3 -- pol1_in3
set_property LOC RAMB18_X3Y70 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y71 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y72 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y73 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y74 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y75 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y76 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X4 -- pol1_in4
set_property LOC RAMB18_X4Y70 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y71 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y72 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y73 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y74 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y75 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y76 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]

# FFT Wideband Real BRAMs -- 4 columns following left-to-right data flow
# Column X5 -- biplex_core twiddle ROMs + reorder_even
set_property LOC RAMB18_X5Y70 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_6/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y71 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_7/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y72 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_8/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y73 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_9/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y74 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y75 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y76 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/map1/xpm_memory_sprom_inst/*/*_reg}]
# Column X6 -- reorder_odd + delay0/delay1
set_property LOC RAMB18_X6Y70 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y71 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y72 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y73 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y74 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X6Y75 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y76 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
# Column X7 -- reorder_out
set_property LOC RAMB18_X7Y70 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y71 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y72 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y73 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y74 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y75 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y76 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y77 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y78 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/map1/xpm_memory_sprom_inst/*/*_reg}]
# Column X6 (top) -- fft_direct butterflies (moved from X8 for correlator)
set_property LOC RAMB18_X6Y77 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly0_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y78 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y79 [get_cells {chfpga0/chan_array0/chan_gen[0]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_1/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]

# # add_cells_to_pblock [get_pblocks CHAN0] [get_cells -quiet [list {chfpga0/chan_array0/chan_gen[0].chan0}]]

# PFB BRAMs -- CHAN[1] (base Y60)
# Column X1 -- pol1_in1
set_property LOC RAMB18_X1Y60 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y61 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y62 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y63 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y64 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y65 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y66 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X2 -- pol1_in2
set_property LOC RAMB18_X2Y60 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y61 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y62 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y63 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y64 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y65 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y66 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X3 -- pol1_in3
set_property LOC RAMB18_X3Y60 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y61 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y62 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y63 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y64 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y65 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y66 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X4 -- pol1_in4
set_property LOC RAMB18_X4Y60 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y61 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y62 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y63 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y64 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y65 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y66 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]

# FFT Wideband Real BRAMs -- CHAN[1] (base Y60)
set_property LOC RAMB18_X5Y60 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_6/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y61 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_7/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y62 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_8/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y63 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_9/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y64 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y65 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y66 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y60 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y61 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y62 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y63 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y64 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X6Y65 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y66 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X7Y60 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y61 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y62 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y63 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y64 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y65 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y66 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y67 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y68 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y67 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly0_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y68 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y69 [get_cells {chfpga0/chan_array0/chan_gen[1]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_1/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]

# PFB BRAMs -- CHAN[2] (base Y50)
# Column X1 -- pol1_in1
set_property LOC RAMB18_X1Y50 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y51 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y52 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y53 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y54 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y55 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y56 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X2 -- pol1_in2
set_property LOC RAMB18_X2Y50 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y51 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y52 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y53 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y54 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y55 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y56 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X3 -- pol1_in3
set_property LOC RAMB18_X3Y50 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y51 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y52 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y53 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y54 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y55 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y56 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X4 -- pol1_in4
set_property LOC RAMB18_X4Y50 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y51 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y52 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y53 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y54 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y55 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y56 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]

# FFT Wideband Real BRAMs -- CHAN[2] (base Y50)
set_property LOC RAMB18_X5Y50 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_6/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y51 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_7/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y52 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_8/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y53 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_9/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y54 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y55 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y56 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y50 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y51 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y52 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y53 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y54 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X6Y55 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y56 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X7Y50 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y51 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y52 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y53 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y54 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y55 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y56 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y57 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y58 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y57 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly0_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y58 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y59 [get_cells {chfpga0/chan_array0/chan_gen[2]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_1/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]

# PFB BRAMs -- CHAN[3] (base Y40)
# Column X1 -- pol1_in1
set_property LOC RAMB18_X1Y40 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y41 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y42 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y43 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y44 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y45 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y46 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X2 -- pol1_in2
set_property LOC RAMB18_X2Y40 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y41 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y42 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y43 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y44 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y45 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y46 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X3 -- pol1_in3
set_property LOC RAMB18_X3Y40 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y41 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y42 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y43 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y44 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y45 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y46 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X4 -- pol1_in4
set_property LOC RAMB18_X4Y40 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y41 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y42 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y43 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y44 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y45 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y46 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]

# FFT Wideband Real BRAMs -- CHAN[3] (base Y40)
set_property LOC RAMB18_X5Y40 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_6/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y41 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_7/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y42 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_8/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y43 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_9/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y44 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y45 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y46 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y40 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y41 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y42 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y43 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y44 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X6Y45 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y46 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X7Y40 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y41 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y42 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y43 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y44 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y45 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y46 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y47 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y48 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y47 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly0_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y48 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y49 [get_cells {chfpga0/chan_array0/chan_gen[3]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_1/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]

# PFB BRAMs -- CHAN[4] (base Y0)
# Column X1 -- pol1_in1
set_property LOC RAMB18_X1Y0 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y1 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y2 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y3 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y4 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y5 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y6 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X2 -- pol1_in2
set_property LOC RAMB18_X2Y0 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y1 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y2 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y3 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y4 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y5 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y6 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X3 -- pol1_in3
set_property LOC RAMB18_X3Y0 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y1 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y2 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y3 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y4 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y5 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y6 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X4 -- pol1_in4
set_property LOC RAMB18_X4Y0 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y1 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y2 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y3 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y4 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y5 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y6 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]

# FFT Wideband Real BRAMs -- CHAN[4] (base Y0)
set_property LOC RAMB18_X5Y0 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_6/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y1 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_7/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y2 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_8/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y3 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_9/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y4 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y5 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y6 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y0 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y1 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y2 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y3 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y4 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X6Y5 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y6 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X7Y0 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y1 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y2 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y3 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y4 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y5 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y6 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y7 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y8 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y7 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly0_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y8 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y9 [get_cells {chfpga0/chan_array0/chan_gen[4]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_1/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]

# PFB BRAMs -- CHAN[5] (base Y10)
# Column X1 -- pol1_in1
set_property LOC RAMB18_X1Y10 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y11 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y12 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y13 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y14 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y15 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y16 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X2 -- pol1_in2
set_property LOC RAMB18_X2Y10 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y11 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y12 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y13 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y14 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y15 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y16 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X3 -- pol1_in3
set_property LOC RAMB18_X3Y10 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y11 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y12 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y13 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y14 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y15 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y16 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X4 -- pol1_in4
set_property LOC RAMB18_X4Y10 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y11 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y12 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y13 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y14 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y15 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y16 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]

# FFT Wideband Real BRAMs -- CHAN[5] (base Y10)
set_property LOC RAMB18_X5Y10 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_6/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y11 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_7/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y12 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_8/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y13 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_9/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y14 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y15 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y16 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y10 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y11 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y12 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y13 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y14 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X6Y15 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y16 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X7Y10 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y11 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y12 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y13 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y14 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y15 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y16 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y17 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y18 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y17 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly0_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y18 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y19 [get_cells {chfpga0/chan_array0/chan_gen[5]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_1/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]

# PFB BRAMs -- CHAN[6] (base Y20)
# Column X1 -- pol1_in1
set_property LOC RAMB18_X1Y20 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y21 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y22 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y23 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y24 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y25 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y26 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X2 -- pol1_in2
set_property LOC RAMB18_X2Y20 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y21 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y22 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y23 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y24 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y25 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y26 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X3 -- pol1_in3
set_property LOC RAMB18_X3Y20 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y21 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y22 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y23 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y24 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y25 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y26 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X4 -- pol1_in4
set_property LOC RAMB18_X4Y20 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y21 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y22 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y23 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y24 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y25 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y26 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]

# FFT Wideband Real BRAMs -- CHAN[6] (base Y20)
set_property LOC RAMB18_X5Y20 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_6/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y21 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_7/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y22 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_8/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y23 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_9/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y24 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y25 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y26 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y20 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y21 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y22 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y23 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y24 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X6Y25 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y26 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X7Y20 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y21 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y22 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y23 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y24 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y25 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y26 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y27 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y28 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y27 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly0_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y28 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y29 [get_cells {chfpga0/chan_array0/chan_gen[6]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_1/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]

# PFB BRAMs -- CHAN[7] (base Y30)
# Column X1 -- pol1_in1
set_property LOC RAMB18_X1Y30 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y31 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y32 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y33 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y34 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y35 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y36 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X2 -- pol1_in2
set_property LOC RAMB18_X2Y30 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y31 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y32 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y33 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y34 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y35 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y36 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X3 -- pol1_in3
set_property LOC RAMB18_X3Y30 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y31 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y32 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y33 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y34 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y35 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y36 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X4 -- pol1_in4
set_property LOC RAMB18_X4Y30 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y31 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y32 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y33 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y34 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y35 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y36 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]

# FFT Wideband Real BRAMs -- CHAN[7] (base Y30)
set_property LOC RAMB18_X5Y30 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_6/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y31 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_7/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y32 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_8/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y33 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_9/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y34 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y35 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y36 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y30 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y31 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y32 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y33 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y34 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X6Y35 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y36 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X7Y30 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y31 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y32 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y33 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y34 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y35 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y36 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y37 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y38 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y37 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly0_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y38 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y39 [get_cells {chfpga0/chan_array0/chan_gen[7]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_1/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]

# PFB BRAMs -- CHAN[8] (base Y110)
# Column X1 -- pol1_in1
set_property LOC RAMB18_X1Y110 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y111 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y112 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y113 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y114 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y115 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y116 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X2 -- pol1_in2
set_property LOC RAMB18_X2Y110 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y111 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y112 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y113 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y114 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y115 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y116 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X3 -- pol1_in3
set_property LOC RAMB18_X3Y110 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y111 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y112 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y113 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y114 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y115 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y116 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X4 -- pol1_in4
set_property LOC RAMB18_X4Y110 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y111 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y112 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y113 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y114 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y115 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y116 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]

# FFT Wideband Real BRAMs -- CHAN[8] (base Y110)
set_property LOC RAMB18_X5Y110 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_6/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y111 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_7/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y112 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_8/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y113 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_9/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y114 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y115 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y116 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y110 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y111 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y112 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y113 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y114 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X6Y115 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y116 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X7Y110 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y111 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y112 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y113 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y114 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y115 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y116 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y117 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y118 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y117 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly0_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y118 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y119 [get_cells {chfpga0/chan_array0/chan_gen[8]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_1/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]

# PFB BRAMs -- CHAN[9] (base Y100)
# Column X1 -- pol1_in1
set_property LOC RAMB18_X1Y100 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y101 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y102 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y103 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y104 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y105 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y106 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X2 -- pol1_in2
set_property LOC RAMB18_X2Y100 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y101 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y102 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y103 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y104 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y105 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y106 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X3 -- pol1_in3
set_property LOC RAMB18_X3Y100 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y101 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y102 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y103 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y104 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y105 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y106 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X4 -- pol1_in4
set_property LOC RAMB18_X4Y100 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y101 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y102 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y103 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y104 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y105 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y106 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]

# FFT Wideband Real BRAMs -- CHAN[9] (base Y100)
set_property LOC RAMB18_X5Y100 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_6/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y101 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_7/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y102 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_8/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y103 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_9/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y104 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y105 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y106 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y100 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y101 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y102 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y103 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y104 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X6Y105 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y106 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X7Y100 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y101 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y102 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y103 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y104 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y105 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y106 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y107 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y108 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y107 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly0_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y108 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y109 [get_cells {chfpga0/chan_array0/chan_gen[9]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_1/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]

# PFB BRAMs -- CHAN[10] (base Y120)
# Column X1 -- pol1_in1
set_property LOC RAMB18_X1Y120 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y121 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y122 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y123 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y124 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y125 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y126 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X2 -- pol1_in2
set_property LOC RAMB18_X2Y120 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y121 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y122 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y123 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y124 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y125 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y126 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X3 -- pol1_in3
set_property LOC RAMB18_X3Y120 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y121 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y122 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y123 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y124 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y125 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y126 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X4 -- pol1_in4
set_property LOC RAMB18_X4Y120 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y121 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y122 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y123 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y124 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y125 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y126 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]

# FFT Wideband Real BRAMs -- CHAN[10] (base Y120)
set_property LOC RAMB18_X5Y120 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_6/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y121 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_7/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y122 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_8/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y123 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_9/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y124 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y125 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y126 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y120 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y121 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y122 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y123 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y124 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X6Y125 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y126 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X7Y120 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y121 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y122 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y123 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y124 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y125 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y126 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y127 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y128 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y127 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly0_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y128 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y129 [get_cells {chfpga0/chan_array0/chan_gen[10]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_1/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]

# PFB BRAMs -- CHAN[11] (base Y130)
# Column X1 -- pol1_in1
set_property LOC RAMB18_X1Y130 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y131 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y132 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y133 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y134 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y135 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y136 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X2 -- pol1_in2
set_property LOC RAMB18_X2Y130 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y131 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y132 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y133 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y134 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y135 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y136 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X3 -- pol1_in3
set_property LOC RAMB18_X3Y130 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y131 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y132 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y133 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y134 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y135 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y136 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X4 -- pol1_in4
set_property LOC RAMB18_X4Y130 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y131 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y132 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y133 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y134 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y135 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y136 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]

# FFT Wideband Real BRAMs -- CHAN[11] (base Y130)
set_property LOC RAMB18_X5Y130 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_6/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y131 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_7/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y132 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_8/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y133 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_9/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y134 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y135 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y136 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y130 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y131 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y132 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y133 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y134 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X6Y135 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y136 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X7Y130 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y131 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y132 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y133 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y134 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y135 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y136 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y137 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y138 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y137 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly0_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y138 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y139 [get_cells {chfpga0/chan_array0/chan_gen[11]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_1/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]

# PFB BRAMs -- CHAN[12] (base Y80)
# Column X1 -- pol1_in1
set_property LOC RAMB18_X1Y80 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y81 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y82 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y83 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y84 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y85 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y86 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X2 -- pol1_in2
set_property LOC RAMB18_X2Y80 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y81 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y82 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y83 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y84 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y85 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y86 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X3 -- pol1_in3
set_property LOC RAMB18_X3Y80 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y81 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y82 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y83 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y84 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y85 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y86 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X4 -- pol1_in4
set_property LOC RAMB18_X4Y80 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y81 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y82 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y83 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y84 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y85 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y86 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]

# FFT Wideband Real BRAMs -- CHAN[12] (base Y80)
set_property LOC RAMB18_X5Y80 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_6/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y81 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_7/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y82 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_8/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y83 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_9/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y84 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y85 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y86 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y80 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y81 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y82 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y83 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y84 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X6Y85 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y86 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X7Y80 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y81 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y82 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y83 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y84 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y85 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y86 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y87 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y88 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y87 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly0_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y88 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y89 [get_cells {chfpga0/chan_array0/chan_gen[12]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_1/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]

# PFB BRAMs -- CHAN[13] (base Y90)
# Column X1 -- pol1_in1
set_property LOC RAMB18_X1Y90 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y91 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y92 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y93 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y94 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y95 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y96 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X2 -- pol1_in2
set_property LOC RAMB18_X2Y90 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y91 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y92 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y93 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y94 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y95 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y96 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X3 -- pol1_in3
set_property LOC RAMB18_X3Y90 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y91 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y92 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y93 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y94 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y95 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y96 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X4 -- pol1_in4
set_property LOC RAMB18_X4Y90 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y91 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y92 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y93 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y94 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y95 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y96 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]

# FFT Wideband Real BRAMs -- CHAN[13] (base Y90)
set_property LOC RAMB18_X5Y90 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_6/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y91 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_7/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y92 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_8/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y93 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_9/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y94 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y95 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y96 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y90 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y91 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y92 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y93 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y94 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X6Y95 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y96 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X7Y90 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y91 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y92 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y93 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y94 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y95 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y96 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y97 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y98 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y97 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly0_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y98 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y99 [get_cells {chfpga0/chan_array0/chan_gen[13]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_1/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]

# PFB BRAMs -- CHAN[14] (base Y150)
# Column X1 -- pol1_in1
set_property LOC RAMB18_X1Y150 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y151 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y152 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y153 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y154 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y155 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y156 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X2 -- pol1_in2
set_property LOC RAMB18_X2Y150 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y151 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y152 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y153 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y154 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y155 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y156 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X3 -- pol1_in3
set_property LOC RAMB18_X3Y150 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y151 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y152 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y153 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y154 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y155 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y156 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X4 -- pol1_in4
set_property LOC RAMB18_X4Y150 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y151 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y152 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y153 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y154 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y155 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y156 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]

# FFT Wideband Real BRAMs -- CHAN[14] (base Y150)
set_property LOC RAMB18_X5Y150 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_6/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y151 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_7/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y152 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_8/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y153 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_9/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y154 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y155 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y156 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y150 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y151 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y152 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y153 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y154 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X6Y155 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y156 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X7Y150 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y151 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y152 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y153 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y154 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y155 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y156 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y157 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y158 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y157 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly0_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y158 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y159 [get_cells {chfpga0/chan_array0/chan_gen[14]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_1/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]

# PFB BRAMs -- CHAN[15] (base Y140)
# Column X1 -- pol1_in1
set_property LOC RAMB18_X1Y140 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y141 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y142 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y143 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X1Y144 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y145 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X1Y146 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in1_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X2 -- pol1_in2
set_property LOC RAMB18_X2Y140 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y141 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y142 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y143 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X2Y144 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y145 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X2Y146 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in2_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X3 -- pol1_in3
set_property LOC RAMB18_X3Y140 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y141 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y142 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y143 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X3Y144 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y145 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X3Y146 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in3_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]
# Column X4 -- pol1_in4
set_property LOC RAMB18_X4Y140 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y141 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom2/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y142 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom3/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y143 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_coeffs/rom4/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X4Y144 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_first_tap/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y145 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap2/delay_bram/ram/xpm_memory*/*/*_reg}]
set_property LOC RAMB18_X4Y146 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/pfb_fir_real/pol1_in4_tap3/delay_bram/ram/xpm_memory*/*/*_reg}]

# FFT Wideband Real BRAMs -- CHAN[15] (base Y140)
set_property LOC RAMB18_X5Y140 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_6/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y141 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_7/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y142 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_8/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y143 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/biplex_core/fft_stage_9/butterfly_direct/twiddle_x0/coeff_gen/cosin/rom/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X5Y144 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y145 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X5Y146 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_even/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y140 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y141 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X6Y142 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_odd/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y143 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y144 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay0/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X6Y145 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_0}]
set_property LOC RAMB18_X6Y146 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/delay1/ram/xpm_memory_spram_inst/xpm_memory_base_inst/gen_wr_a.gen_word_narrow.mem_reg_1}]
set_property LOC RAMB18_X7Y140 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y141 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf0/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y142 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y143 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf1/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y144 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y145 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf2/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y146 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram0/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y147 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/buf3/bram1/xpm_memory_spram_inst/*/*_reg}]
set_property LOC RAMB18_X7Y148 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_biplex_real_4x/bi_real_unscr_4x/reorder_out/map1/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y147 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly0_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y148 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_0/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]
set_property LOC RAMB18_X6Y149 [get_cells {chfpga0/chan_array0/chan_gen[15]*/*fft0/*fft0/U0/*/fft_wideband_real/fft_direct/butterfly1_1/twiddle_x0/coeff_gen/feedback_osc/reference_values/xpm_memory_sprom_inst/*/*_reg}]

