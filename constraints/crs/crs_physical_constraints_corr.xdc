############################################################################
##
##   CRS Rev1 & Rev2 Physical constraints
##  Correlator config-specific constraints
##
############################################################################



############################################################################
# Corner-turn engine
############################################################################

create_pblock CORN
add_cells_to_pblock [get_pblocks CORN] [get_cells -quiet [list chfpga0/ct_gen.ct_case.uct_case.ct0]]
resize_pblock [get_pblocks CORN] -add {SLICE_X6Y360:SLICE_X11Y419 SLICE_X0Y330:SLICE_X5Y419}
resize_pblock [get_pblocks CORN] -add {BUFG_GT_X0Y144:BUFG_GT_X0Y191}
resize_pblock [get_pblocks CORN] -add {BUFG_GT_SYNC_X0Y90:BUFG_GT_SYNC_X0Y119}
resize_pblock [get_pblocks CORN] -add {DSP48E2_X0Y144:DSP48E2_X0Y167}
resize_pblock [get_pblocks CORN] -add {RAMB18_X0Y144:RAMB18_X0Y167}
resize_pblock [get_pblocks CORN] -add {RAMB36_X0Y72:RAMB36_X0Y83}
set_property IS_SOFT FALSE [get_pblocks CORN]





