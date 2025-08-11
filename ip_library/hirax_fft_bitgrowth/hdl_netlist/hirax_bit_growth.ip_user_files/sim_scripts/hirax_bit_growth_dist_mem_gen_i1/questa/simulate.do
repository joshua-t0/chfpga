onbreak {quit -f}
onerror {quit -f}

vsim  -lib xil_defaultlib hirax_bit_growth_dist_mem_gen_i1_opt

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure
view signals

do {hirax_bit_growth_dist_mem_gen_i1.udo}

run 1000ns

quit -force
