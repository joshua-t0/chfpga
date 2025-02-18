############################################################################
##
##   CRS Rev1 & Rev2 Physical constraints
##  Correlator config-specific constraints
##
############################################################################


create_pblock CORR
add_cells_to_pblock [get_pblocks CORR] [get_cells -quiet [list chfpga0/CORRGEN.corr_sel_gen.ucorr44_case.ucorr44_array0]]
resize_pblock [get_pblocks CORR] -add {SLICE_X12Y180:SLICE_X25Y419 SLICE_X6Y180:SLICE_X11Y359}
resize_pblock [get_pblocks CORR] -add {DSP48E2_X1Y72:DSP48E2_X2Y167 DSP48E2_X0Y72:DSP48E2_X0Y143}
resize_pblock [get_pblocks CORR] -add {PCIE4CE4_X0Y0:PCIE4CE4_X0Y0}
resize_pblock [get_pblocks CORR] -add {RAMB18_X1Y72:RAMB18_X1Y167 RAMB18_X0Y72:RAMB18_X0Y143}
resize_pblock [get_pblocks CORR] -add {RAMB36_X1Y36:RAMB36_X1Y83 RAMB36_X0Y36:RAMB36_X0Y71}
resize_pblock [get_pblocks CORR] -add {URAM288_X0Y0:URAM288_X0Y63}
set_property IS_SOFT FALSE [get_pblocks CORR]
#add_cells_to_pblock [get_pblocks CORR] [get_cells -quiet [list chfpga0/CORRGEN.corr_array0]]














