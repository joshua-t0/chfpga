create_clock -period 2.500 -name clk -waveform {0.000 1.250} [get_ports clk]
create_clock -period 8.000 -name ctrl_clk -waveform {0.000 4.000} [get_ports ctrl_clk]

create_pblock FUNCGEN
add_cells_to_pblock [get_pblocks FUNCGEN] -top
resize_pblock [get_pblocks FUNCGEN] -add {SLICE_X51Y140:SLICE_X58Y179}
resize_pblock [get_pblocks FUNCGEN] -add {DSP48E2_X9Y56:DSP48E2_X9Y71}
resize_pblock [get_pblocks FUNCGEN] -add {RAMB18_X5Y56:RAMB18_X5Y71}
resize_pblock [get_pblocks FUNCGEN] -add {RAMB36_X5Y28:RAMB36_X5Y35}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks FUNCGEN]
set_clock_groups -name CLK125 -asynchronous -group [get_clocks ctrl_clk]


