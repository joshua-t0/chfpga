#!/usr/bin/env -S vivado -mode batch -source

cd ../xilinx_projects/chfpga_crs_corr64
source create_project.tcl

cd ../../test
add_files { hdl/chfpga_crssim.vhd hdl/stubs.vhd }
set_property file_type "VHDL 2008" -objects [get_files { chfpga_crssim.vhd stubs.vhd }]

set_property -name top -value chfpga_crssim -objects [get_filesets sim_1]
export_simulation -force -simulator xsim

quit
