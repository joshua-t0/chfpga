create_pblock crossbar2
add_cells_to_pblock [get_pblocks crossbar2] -top
resize_pblock [get_pblocks crossbar2] -add {SLICE_X136Y223:SLICE_X175Y25}
resize_pblock [get_pblocks crossbar2] -add {DSP48_X9Y10:DSP48_X10Y87}
resize_pblock [get_pblocks crossbar2] -add {RAMB18_X9Y87:RAMB18_X11Y10}
resize_pblock [get_pblocks crossbar2] -add {RAMB36_X9Y43:RAMB36_X11Y5}
create_clock -period 4.000 -name clk [get_ports clk]
create_clock -period 8.000 -name ctrl_clk -waveform {0.000 4.000} [get_ports ctrl_clk]


set_clock_groups -name ctrl_clk_group -asynchronous -group [get_clocks ctrl_clk]
