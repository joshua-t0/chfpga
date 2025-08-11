onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+hirax_bit_growth_dist_mem_gen_i2  -L xpm -L dist_mem_gen_v8_0_13 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.hirax_bit_growth_dist_mem_gen_i2 xil_defaultlib.glbl

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure

do {hirax_bit_growth_dist_mem_gen_i2.udo}

run

endsim

quit -force
