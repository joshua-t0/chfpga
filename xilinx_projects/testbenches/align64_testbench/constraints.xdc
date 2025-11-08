create_clock -period 2.500 -name clk -waveform {0.000 1.250} [get_ports clk]
create_pblock ALIGN64
add_cells_to_pblock [get_pblocks ALIGN64] -top
resize_pblock [get_pblocks ALIGN64] -add {SLICE_X32Y65:SLICE_X32Y84}
resize_pblock [get_pblocks ALIGN64] -add {RAMB18_X3Y26:RAMB18_X3Y33}
resize_pblock [get_pblocks ALIGN64] -add {RAMB36_X3Y13:RAMB36_X3Y16}

