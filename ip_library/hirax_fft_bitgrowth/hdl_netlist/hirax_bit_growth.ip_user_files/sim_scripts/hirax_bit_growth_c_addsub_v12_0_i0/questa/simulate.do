onbreak {quit -f}
onerror {quit -f}

vsim  -lib xil_defaultlib hirax_bit_growth_c_addsub_v12_0_i0_opt

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure
view signals

do {hirax_bit_growth_c_addsub_v12_0_i0.udo}

run 1000ns

quit -force
