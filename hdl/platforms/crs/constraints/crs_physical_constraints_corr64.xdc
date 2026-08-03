############################################################################
##
##   CRS Rev1 & Rev2 Physical constraints
##  Correlator config-specific constraints
##
############################################################################


# GTY reference clock MGTREFCLK0, 156.25 MHz from fixed PLL, Bank 131
# Corner-turn engine GTY reference clock
set_property PACKAGE_PIN W33 [get_ports {bp_shuffle_refclk_p[1]}]
create_clock -period 6.400 -name CLK_BP_SHUFFLE_REFCLK129 [get_ports {bp_shuffle_refclk_p[1]}]
# set_property PACKAGE_PIN U33 [get_ports {bp_shuffle_refclk_p[1]}]

# LOCs below was for GTY REFCLK1, but we can't route it to BUFG_GT_SYNC
#set_property LOC BUFG_GT_X0Y134 [get_cells {chfpga0/ct_gen.ct_case.uct_case.ct0/ct1_blk.ct2_gen.bp_links0/core0/refclk_blk.ibuf_gen[1].refclk_bufg0}]
#set_property LOC BUFG_GT_SYNC_X0Y89 [get_cells {chfpga0/ct_gen.ct_case.uct_case.ct0/ct1_blk.ct2_gen.bp_links0/core0/BUFG_GT_SYNC_1}]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets chfpga0/ct_gen.ct_case.uct_case.ct0/ct1_blk.ct2_gen.bp_links0/core0/refclk_blk.refclk_div_nobuf_0]


create_pblock CORN
add_cells_to_pblock [get_pblocks CORN] [get_cells -quiet [list chfpga0/ct_gen.ct_case.uct_case.ct0]]
resize_pblock [get_pblocks CORN] -add {SLICE_X0Y360:SLICE_X11Y419 SLICE_X9Y240:SLICE_X9Y359 SLICE_X0Y180:SLICE_X5Y359}
resize_pblock [get_pblocks CORN] -add {BUFG_GT_X0Y144:BUFG_GT_X0Y191}
resize_pblock [get_pblocks CORN] -add {BUFG_GT_SYNC_X0Y90:BUFG_GT_SYNC_X0Y119}
resize_pblock [get_pblocks CORN] -add {DSP48E2_X0Y144:DSP48E2_X0Y167}
resize_pblock [get_pblocks CORN] -add {RAMB18_X0Y96:RAMB18_X0Y167}
resize_pblock [get_pblocks CORN] -add {RAMB36_X0Y48:RAMB36_X0Y83}
set_property IS_SOFT FALSE [get_pblocks CORN]

#ALIGN1 FIFO LOCs
set_property LOC RAMB36_X0Y72 [get_cells {chfpga0/ct_gen*/*align1/fifogen[0]*/*_fifo0}]
set_property LOC RAMB36_X0Y73 [get_cells {chfpga0/ct_gen*/*align1/fifogen[1]*/*_fifo0}]
set_property LOC RAMB36_X0Y74 [get_cells {chfpga0/ct_gen*/*align1/fifogen[2]*/*_fifo0}]
set_property LOC RAMB36_X0Y75 [get_cells {chfpga0/ct_gen*/*align1/fifogen[3]*/*_fifo0}]

