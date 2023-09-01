create_pblock pblock_chan
add_cells_to_pblock [get_pblocks pblock_chan] -top
resize_pblock [get_pblocks pblock_chan] -add {SLICE_X12Y420:SLICE_X118Y479}
resize_pblock [get_pblocks pblock_chan] -add {DSP48E2_X1Y168:DSP48E2_X22Y191}
resize_pblock [get_pblocks pblock_chan] -add {RAMB18_X1Y168:RAMB18_X11Y191}
resize_pblock [get_pblocks pblock_chan] -add {RAMB36_X1Y84:RAMB36_X11Y95}
