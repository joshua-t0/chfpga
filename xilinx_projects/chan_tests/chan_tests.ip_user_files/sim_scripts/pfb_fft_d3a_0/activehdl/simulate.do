onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+pfb_fft_d3a_0  -L xpm -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.pfb_fft_d3a_0 xil_defaultlib.glbl

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure

do {pfb_fft_d3a_0.udo}

run

endsim

quit -force
