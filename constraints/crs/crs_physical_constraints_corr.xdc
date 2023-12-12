############################################################################
##
##   CRS Rev1 & Rev2 Physical constraints
##  Correlator config-specific constraints
##
############################################################################


create_pblock CORR
add_cells_to_pblock [get_pblocks CORR] [get_cells -quiet [list chfpga0/CORRGEN.corr_sel_gen.ucorr44_case.ucorr44_array0]]
resize_pblock [get_pblocks CORR] -add {SLICE_X0Y180:SLICE_X25Y419}
resize_pblock [get_pblocks CORR] -add {DSP48E2_X0Y72:DSP48E2_X2Y167}
resize_pblock [get_pblocks CORR] -add {PCIE4CE4_X0Y0:PCIE4CE4_X0Y0}
resize_pblock [get_pblocks CORR] -add {RAMB18_X0Y72:RAMB18_X1Y167}
resize_pblock [get_pblocks CORR] -add {RAMB36_X0Y36:RAMB36_X1Y83}
resize_pblock [get_pblocks CORR] -add {URAM288_X0Y0:URAM288_X0Y63}
set_property IS_SOFT FALSE [get_pblocks CORR]
#add_cells_to_pblock [get_pblocks CORR] [get_cells -quiet [list chfpga0/CORRGEN.corr_array0]]








set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets smp_OBUF[3]]
