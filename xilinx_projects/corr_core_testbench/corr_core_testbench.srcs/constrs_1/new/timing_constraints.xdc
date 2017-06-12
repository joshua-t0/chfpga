create_clock -period 2.330 -name in_clk -add [get_ports in_clk]
create_clock -period 8.000 -name out_clk -add [get_ports out_clk]
create_clock -period 8.000 -name ctrl_clk -add [get_ports ctrl_clk]


# create_pblock pblock_1
# add_cells_to_pblock [get_pblocks pblock_1] -top
# resize_pblock [get_pblocks pblock_1] -add {SLICE_X82Y125:SLICE_X85Y199}
# resize_pblock [get_pblocks pblock_1] -add {DSP48_X5Y50:DSP48_X5Y79}
# resize_pblock [get_pblocks pblock_1] -add {RAMB18_X5Y50:RAMB18_X5Y79}
# resize_pblock [get_pblocks pblock_1] -add {RAMB36_X5Y25:RAMB36_X5Y39}


# create_pblock pblock_2
# add_cells_to_pblock [get_pblocks pblock_2] [get_cells *]
# resize_pblock [get_pblocks pblock_2] -add {SLICE_X82Y180:SLICE_X85Y184}
# resize_pblock [get_pblocks pblock_2] -add {DSP48_X5Y72:DSP48_X5Y73}
# resize_pblock [get_pblocks pblock_2] -add {RAMB18_X5Y72:RAMB18_X5Y73}
# resize_pblock [get_pblocks pblock_2] -add {RAMB36_X5Y36:RAMB36_X5Y36}




# create_pblock CORR44
# add_cells_to_pblock [get_pblocks CORR44] -top
# resize_pblock [get_pblocks CORR44] -add {SLICE_X8Y50:SLICE_X23Y134}
# resize_pblock [get_pblocks CORR44] -add {DSP48_X0Y20:DSP48_X1Y53}
# resize_pblock [get_pblocks CORR44] -add {RAMB18_X0Y20:RAMB18_X1Y53}
# resize_pblock [get_pblocks CORR44] -add {RAMB36_X0Y10:RAMB36_X1Y26}



set_clock_groups -asynchronous -group [get_clocks ctrl_clk]
set_clock_groups -asynchronous -group [get_clocks out_clk]
set_clock_groups -asynchronous -group [get_clocks in_clk]
